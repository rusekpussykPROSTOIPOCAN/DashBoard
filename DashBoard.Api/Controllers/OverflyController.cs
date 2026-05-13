using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/overfly")]
    public class OverflyController : BaseController
    {
        public OverflyController(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet("districts")]
        public async Task<IActionResult> GetDistricts()
        {
            var districts = await _dashboard.districts
                .Select(d => new SelectItem { Id = d.id, Name = d.name })
                .ToListAsync();
            return Ok(districts);
        }

        [HttpGet("statuses")]
        public async Task<IActionResult> GetStatuses()
        {
            var statuses = await _dashboard.statusapplications
                .Select(s => new SelectItem { Id = s.id, Name = s.name })
                .ToListAsync();
            return Ok(statuses);
        }

        [HttpGet("addresses")]
        public async Task<IActionResult> GetAddresses()
        {
            var addresses = await _dashboard.addresses
                .Select(a => new SelectItem { Id = a.id, Name = a.address1 })
                .ToListAsync();
            return Ok(addresses);
        }

        [HttpGet("violations")]
        public async Task<IActionResult> GetViolations()
        {
            var violations = await _dashboard.violations
                .Select(v => new SelectItem { Id = v.id, Name = v.name })
                .ToListAsync();
            return Ok(violations);
        }

        [HttpGet("block-2-all")]
        public async Task<IActionResult> GetBlock2All()
        {
            var data = await _dashboard.overfly_block2s
                .Include(o => o.id_statusNavigation)
                .Include(o => o.id_addressNavigation)
                .Include(o => o.id_districtNavigation)
                .Select(o => new OverflyBlock2Item
                {
                    Id = o.id,
                    IdStatus = o.id_status,
                    StatusName = o.id_statusNavigation.name,
                    IdAddress = o.id_address,
                    AddressName = o.id_addressNavigation.address1,
                    IdDistrict = o.id_district,
                    DistrictName = o.id_districtNavigation.name,
                    Square = o.square,
                    DateGetMaterials = o.date_get_materials
                })
                .OrderByDescending(o => o.Id)
                .ToListAsync();
            return Ok(data);
        }
        [HttpPost("block-2")]
        public async Task<IActionResult> CreateBlock2([FromBody] OverflyBlock2Request request)
        {
            try
            {
                int? addressId = null;

                if (!string.IsNullOrWhiteSpace(request.AddressName))
                {
                    var normalizedName = request.AddressName.Trim();

                    var existingAddress = await _dashboard.addresses
                        .FirstOrDefaultAsync(a => a.address1.ToLower() == normalizedName.ToLower());

                    if (existingAddress != null)
                    {
                        addressId = existingAddress.id;
                    }
                    else
                    {
                        var newAddress = new address { address1 = normalizedName };
                        addressId = await SafeAddAddressAsync(newAddress);
                    }
                }
                else if (request.IdAddress.HasValue && request.IdAddress.Value > 0)
                {
                    addressId = request.IdAddress.Value;
                }

                if (!addressId.HasValue)
                    return BadRequest("Не указан адрес");

                var item = new overfly_block2
                {
                    id_status = request.IdStatus,
                    id_address = addressId.Value,
                    id_district = request.IdDistrict,
                    square = request.Square,
                    date_get_materials = request.DateGetMaterials
                };

                _dashboard.overfly_block2s.Add(item);
                await _dashboard.SaveChangesAsync();

                var created = await _dashboard.overfly_block2s
                    .Include(o => o.id_statusNavigation)
                    .Include(o => o.id_addressNavigation)
                    .Include(o => o.id_districtNavigation)
                    .FirstOrDefaultAsync(o => o.id == item.id);

                var result = new OverflyBlock2Item
                {
                    Id = created.id,
                    IdStatus = created.id_status,
                    StatusName = created.id_statusNavigation?.name ?? "",
                    IdAddress = created.id_address,
                    AddressName = created.id_addressNavigation?.address1 ?? "",
                    IdDistrict = created.id_district,
                    DistrictName = created.id_districtNavigation?.name ?? "",
                    Square = created.square,
                    DateGetMaterials = created.date_get_materials
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpPut("block-2/{id}")]
        public async Task<IActionResult> UpdateBlock2(int id, [FromBody] OverflyBlock2Request request)
        {
            try
            {
                var item = await _dashboard.overfly_block2s.FindAsync(id);
                if (item == null) return NotFound();

                int? addressId = null;

                if (!string.IsNullOrWhiteSpace(request.AddressName))
                {
                    var normalizedName = request.AddressName.Trim();

                    var existingAddress = await _dashboard.addresses
                        .FirstOrDefaultAsync(a => a.address1.ToLower() == normalizedName.ToLower());

                    if (existingAddress != null)
                    {
                        addressId = existingAddress.id;
                    }
                    else
                    {
                        var newAddress = new address { address1 = normalizedName };
                        addressId = await SafeAddAddressAsync(newAddress);
                    }
                }
                else if (request.IdAddress.HasValue && request.IdAddress.Value > 0)
                {
                    addressId = request.IdAddress.Value;
                }

                if (!addressId.HasValue)
                    addressId = item.id_address;

                item.id_status = request.IdStatus;
                item.id_address = addressId;
                item.id_district = request.IdDistrict;
                item.square = request.Square;
                item.date_get_materials = request.DateGetMaterials;

                await _dashboard.SaveChangesAsync();
                return Ok(new { message = "Запись обновлена" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpDelete("block-2/{id}")]
        public async Task<IActionResult> DeleteBlock2(int id)
        {
            try
            {
                var item = await _dashboard.overfly_block2s.FindAsync(id);
                if (item == null) return NotFound();

                _dashboard.overfly_block2s.Remove(item);
                await _dashboard.SaveChangesAsync();
                return Ok(new { message = "Запись удалена" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }


        [HttpGet("block-1-all")]
        public async Task<IActionResult> GetBlock1All()
        {
            var data = await _dashboard.overfly_block1s
                .Include(o => o.iddistricNavigation)
                .Include(o => o.idviolationNavigation)
                .Select(o => new OverflyBlock1Item
                {
                    Id = o.id,
                    IdDistrict = o.iddistric,
                    DistrictName = o.iddistricNavigation.name,
                    IdAddress = o.idadress,
                    QuantityNewViolation = o.quantitynewviolation,
                    IdViolation = o.idviolation,
                    ViolationName = o.idviolationNavigation.name,
                    DateDetection = o.date_detection
                })
                .OrderByDescending(o => o.Id)
                .ToListAsync();
            return Ok(data);
        }

        [HttpPost("block-1")]
        public async Task<IActionResult> CreateBlock1([FromBody] OverflyBlock1Request request)
        {
            try
            {
                int? violationId = null;

                if (!string.IsNullOrWhiteSpace(request.ViolationName))
                {
                    var normalizedName = request.ViolationName.Trim();

                    var existingViolation = await _dashboard.violations
                        .FirstOrDefaultAsync(v => v.name.ToLower() == normalizedName.ToLower());

                    if (existingViolation != null)
                    {
                        violationId = existingViolation.id;
                    }
                    else
                    {
                        var newViolation = new violation { name = normalizedName };
                        violationId = await SafeAddViolationAsync(newViolation);
                    }
                }
                else if (request.IdViolation.HasValue && request.IdViolation.Value > 0)
                {
                    violationId = request.IdViolation.Value;
                }

                if (!violationId.HasValue)
                    return BadRequest("Не указано нарушение");

                var item = new overfly_block1
                {
                    iddistric = request.IdDistrict,
                    idadress = request.IdAddress,
                    quantitynewviolation = request.QuantityNewViolation,
                    idviolation = violationId.Value,
                    date_detection = request.DateDetection
                };

                _dashboard.overfly_block1s.Add(item);
                await _dashboard.SaveChangesAsync();

                var created = await _dashboard.overfly_block1s
                    .Include(o => o.iddistricNavigation)
                    .Include(o => o.idviolationNavigation)
                    .FirstOrDefaultAsync(o => o.id == item.id);

                var result = new OverflyBlock1Item
                {
                    Id = created.id,
                    IdDistrict = created.iddistric,
                    DistrictName = created.iddistricNavigation?.name ?? "",
                    IdAddress = created.idadress,
                    QuantityNewViolation = created.quantitynewviolation,
                    IdViolation = created.idviolation,
                    ViolationName = created.idviolationNavigation?.name ?? "",
                    DateDetection = created.date_detection
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpPut("block-1/{id}")]
        public async Task<IActionResult> UpdateBlock1(int id, [FromBody] OverflyBlock1Request request)
        {
            try
            {
                var item = await _dashboard.overfly_block1s.FindAsync(id);
                if (item == null) return NotFound();

                int? violationId = null;

                if (!string.IsNullOrWhiteSpace(request.ViolationName))
                {
                    var normalizedName = request.ViolationName.Trim();

                    var existingViolation = await _dashboard.violations
                        .FirstOrDefaultAsync(v => v.name.ToLower() == normalizedName.ToLower());

                    if (existingViolation != null)
                    {
                        violationId = existingViolation.id;
                    }
                    else
                    {
                        var newViolation = new violation { name = normalizedName };
                        violationId = await SafeAddViolationAsync(newViolation);
                    }
                }
                else if (request.IdViolation.HasValue && request.IdViolation.Value > 0)
                {
                    violationId = request.IdViolation.Value;
                }

                if (!violationId.HasValue)
                    violationId = item.idviolation;

                item.iddistric = request.IdDistrict;
                item.idadress = request.IdAddress;
                item.quantitynewviolation = request.QuantityNewViolation;
                item.idviolation = violationId;
                item.date_detection = request.DateDetection;

                await _dashboard.SaveChangesAsync();
                return Ok(new { message = "Запись обновлена" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpDelete("block-1/{id}")]
        public async Task<IActionResult> DeleteBlock1(int id)
        {
            try
            {
                var item = await _dashboard.overfly_block1s.FindAsync(id);
                if (item == null) return NotFound();

                _dashboard.overfly_block1s.Remove(item);
                await _dashboard.SaveChangesAsync();
                return Ok(new { message = "Запись удалена" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpGet("block-1")]
        public async Task<IActionResult> GetBlock1(int? year = null, int? quarter = null, int? month = null)
        {
            try
            {
                var query = _dashboard.overfly_block1s
                    .Include(o => o.iddistricNavigation)
                    .Include(o => o.idviolationNavigation)
                    .AsQueryable();

                if (year.HasValue)
                    query = query.Where(x => x.date_detection.HasValue && x.date_detection.Value.Year == year.Value);
                if (month.HasValue)
                    query = query.Where(x => x.date_detection.HasValue && x.date_detection.Value.Month == month.Value);
                if (quarter.HasValue)
                {
                    var startMonth = (quarter.Value - 1) * 3 + 1;
                    var endMonth = startMonth + 2;
                    query = query.Where(o => o.date_detection.HasValue &&
                                          o.date_detection.Value.Month >= startMonth &&
                                          o.date_detection.Value.Month <= endMonth);
                }

                var data = await query.ToListAsync();

                var totalCount = data.Sum(c => c.quantitynewviolation ?? 0);

                var statusCounts = data
                    .GroupBy(x => x.idviolationNavigation?.name ?? "Неизвестно")
                    .Select(g => new OverflyStatusCount
                    {
                        StatusName = g.Key,
                        Count = g.Count()
                    })
                    .OrderByDescending(d => d.Count)
                    .ToList();

                var dateCounts = data
                    .Where(x => x.date_detection.HasValue)
                    .GroupBy(x => x.date_detection.Value)
                    .Select(x => new OverflyDates
                    {
                        dateFly = x.Key,
                        Count = x.Count(),
                        Year = x.Key.Year,
                        Quarter = (x.Key.Month - 1) / 3 + 1,
                        Month = x.Key.Month
                    })
                    .OrderBy(d => d.dateFly)
                    .ToList();

                var districtCounts = data
                    .GroupBy(o => o.iddistricNavigation?.name ?? "Неизвестно")
                    .Select(g => new OverflyByDistricts
                    {
                        DistrictName = g.Key,
                        Count = g.Count()
                    })
                    .OrderByDescending(d => d.Count)
                    .ToList();

                var result = new OverflyDTO
                {
                    CountStatus = totalCount,
                    overflyStatusCounts = statusCounts,
                    OverflyDates = dateCounts,
                    overflyByDistricts = districtCounts
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка {ex.Message}");
            }
        }

        [HttpGet("get-overfly")]
        public async Task<IActionResult> GetOverfly(int? year = null, int? quarter = null, int? month = null)
        {
            try
            {
                var query = _dashboard.overfly_block2s
                    .Include(o => o.id_statusNavigation)
                    .Include(o => o.id_districtNavigation)
                    .AsQueryable();

                if (year.HasValue)
                    query = query.Where(o => o.date_get_materials.HasValue && o.date_get_materials.Value.Year == year.Value);
                if (quarter.HasValue)
                {
                    var startMonth = (quarter.Value - 1) * 3 + 1;
                    var endMonth = startMonth + 2;
                    query = query.Where(o => o.date_get_materials.HasValue &&
                                          o.date_get_materials.Value.Month >= startMonth &&
                                          o.date_get_materials.Value.Month <= endMonth);
                }
                if (month.HasValue)
                    query = query.Where(x => x.date_get_materials.HasValue && x.date_get_materials.Value.Month == month.Value);

                var data = await query.ToListAsync();
                var totalCount = data.Count();

                var statusCounts = data
                    .GroupBy(x => x.id_statusNavigation?.name ?? "Неизвестно")
                    .Select(g => new OverflyStatusCount
                    {
                        StatusName = g.Key,
                        Count = g.Count()
                    }).ToList();

                var dateCounts = data
                    .Where(x => x.date_get_materials.HasValue)
                    .GroupBy(x => x.date_get_materials.Value)
                    .Select(x => new OverflyDates
                    {
                        dateFly = x.Key,
                        Count = x.Count(),
                        Year = x.Key.Year,
                        Quarter = (x.Key.Month - 1) / 3 + 1,
                        Month = x.Key.Month
                    })
                    .OrderBy(d => d.dateFly)
                    .ToList();

                var districtCounts = data
                    .GroupBy(o => o.id_districtNavigation?.name ?? "Неизвестно")
                    .Select(g => new OverflyByDistricts
                    {
                        DistrictName = g.Key,
                        Count = g.Count()
                    })
                    .OrderByDescending(d => d.Count)
                    .ToList();

                var result = new OverflyDTO
                {
                    CountStatus = totalCount,
                    overflyStatusCounts = statusCounts,
                    OverflyDates = dateCounts,
                    overflyByDistricts = districtCounts
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message}");
            }
        }
        private async Task<int> SafeAddAddressAsync(address newAddress)
        {
            try
            {
                _dashboard.addresses.Add(newAddress);
                await _dashboard.SaveChangesAsync();
                return newAddress.id;
            }
            catch (DbUpdateException)
            {
                _dashboard.Entry(newAddress).State = EntityState.Detached;
                _dashboard.addresses.Add(newAddress);
                await _dashboard.SaveChangesAsync();
                return newAddress.id;
            }
        }

        private async Task<int> SafeAddViolationAsync(violation newViolation)
        {
            try
            {
                _dashboard.violations.Add(newViolation);
                await _dashboard.SaveChangesAsync();
                return newViolation.id;
            }
            catch (DbUpdateException)
            {
                _dashboard.Entry(newViolation).State = EntityState.Detached;
                _dashboard.violations.Add(newViolation);
                await _dashboard.SaveChangesAsync();
                return newViolation.id;
            }
        }

    }
}