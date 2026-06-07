using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api")]
    [IgnoreAntiforgeryToken]
    public class ToFormPageApi : BaseController
    {
        public ToFormPageApi(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet("form/{id}")]
        public async Task<IActionResult> GetWorkProgress(int id)
        {
            try
            {
                var workProgress = await _dashboard.work_progresses
                    .Include(wp => wp.id_sourseNavigation)
                    .Include(wp => wp.work_progress_violations)
                    .FirstOrDefaultAsync(wp => wp.id == id);

                if (workProgress == null)
                    return NotFound($"Запись с ID {id} не найдена");

                var response = new WorkProgressResponce
                {
                    Id = workProgress.id,
                    IdSourse = workProgress.id_sourse ?? 0,
                    SourseName = workProgress.id_sourseNavigation?.source ?? "Неизвестно",
                    AllPerimeter = workProgress.all_perimeter ?? 0,
                    CompletePerimeter = workProgress.complete_perimeter ?? 0,
                    RemainedPerimeter = workProgress.remained_perimeter ?? 0,
                    Comment = workProgress.comment,
                    CreateAt = workProgress.created_at ?? DateTime.Now,
                    Violations = workProgress.work_progress_violations.Select(v => new ViolationsResponse
                    {
                        Id = v.id,
                        IdArticle = v.id_article ?? 0,
                        ArticleName = "",
                        ViolationsWeek = v.object_a_week ?? 0,
                        NewViolations = v.new_violations ?? 0,
                        OldViolations = v.old_violations ?? 0
                    }).ToList()
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при получении данных: {ex.Message}");
            }
        }
        
        [HttpPost("form")]
        [Authorize]
        public async Task<IActionResult> CreateWorkProgress([FromBody] AddWorkProgressRequest request)
        {
            if (request == null)
                return BadRequest("Данные не переданы");

            if (request.Violations == null || !request.Violations.Any())
                return BadRequest("Не выбраны нарушения");

            await using var transaction = await _dashboard.Database.BeginTransactionAsync();
            try
            {
             
                int? actualSourceId = await GetOrCreateSourceAsync(request.IdSourse, request.CustomSourceName);
                var userDepartment = User.FindFirst("Department")?.Value;
                if (!User.IsInRole("Администратор") && userDepartment != "Аналитика")
                    return Forbid();
                if (!actualSourceId.HasValue)
                    return BadRequest("Не выбран источник");

                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                var workProgress = new work_progress
                {
                    id_sourse = actualSourceId,
                    all_perimeter = request.AllPerimeter,
                    complete_perimeter = request.CompletePerimeter,
                    remained_perimeter = request.RemainedPerimeter,
                    comment = request.Comment,
                    created_at = DateTime.Now,
                    created_by_user_id = request.UserId
                };

                _dashboard.work_progresses.Add(workProgress);
                await _dashboard.SaveChangesAsync();

              
                foreach (var violation in request.Violations)
                {
                    int? actualArticleId = await GetOrCreateArticleAsync(
                        violation.IdArticle,
                        violation.CustomArticleName);

                    if (!actualArticleId.HasValue)
                        return BadRequest("Не указана статья для нарушения");

                    var progressViolation = new work_progress_violation
                    {
                        id_work_progress = workProgress.id,
                        id_article = actualArticleId,
                        object_a_week = violation.ViolationsWeek,
                        new_violations = violation.NewViolations,
                        old_violations = violation.OldViolations
                    };
                    _dashboard.work_progress_violations.Add(progressViolation);
                }

                await _dashboard.SaveChangesAsync();
                await transaction.CommitAsync();
                await LogEvent("Добавлена запись", $"Добавлена запись на страницу аналитики", request.UserId);
                return Ok(new AddWorkProgressResult
                {
                    id = workProgress.id,
                    message = "Данные успешно сохранены",
                    violations_count = request.Violations.Count
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, $"Ошибка при сохранении: {ex.Message}");
            }
        }

        [HttpPut("form/{id}")]
        public async Task<IActionResult> UpdateWorkProgress(int id, [FromBody] EditWorkProgressRequest request)
        {
            if (id != request.Id)
                return BadRequest("Несоответствие ID");

            await using var transaction = await _dashboard.Database.BeginTransactionAsync();
            try
            {
                var workProgress = await _dashboard.work_progresses
                    .Include(wp => wp.work_progress_violations)
                    .FirstOrDefaultAsync(wp => wp.id == id);

                if (workProgress == null)
                    return NotFound($"Запись с ID {id} не найдена");

                workProgress.id_sourse = request.IdSourse;
                workProgress.all_perimeter = request.AllPerimeter;
                workProgress.complete_perimeter = request.CompletePerimeter;
                workProgress.remained_perimeter = request.RemainedPerimeter;
                workProgress.comment = request.Comment;
                workProgress.created_by_user_id = request.UserId ?? workProgress.created_by_user_id;

                _dashboard.work_progress_violations.RemoveRange(workProgress.work_progress_violations);

                foreach (var violation in request.Violations)
                {
                    int? actualArticleId = await GetOrCreateArticleAsync(
                        violation.IdArticle,
                        violation.CustomArticleName);

                    _dashboard.work_progress_violations.Add(new work_progress_violation
                    {
                        id_work_progress = workProgress.id,
                        id_article = actualArticleId ?? violation.IdArticle,
                        object_a_week = violation.ViolationsWeek,
                        new_violations = violation.NewViolations,
                        old_violations = violation.OldViolations
                    });
                }

                await _dashboard.SaveChangesAsync();
                await transaction.CommitAsync();
                await LogEvent("Обновлена запись", $"Обновлена запись на странице аналитики", request.UserId);
                return Ok(new { id = workProgress.id, message = "Данные успешно обновлены" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, $"Ошибка при обновлении: {ex.Message}");
            }
        }

        [HttpDelete("form/{id}")]
        public async Task<IActionResult> DeleteWorkProgress(int id)
        {
            try
            {
                var workProgress = await _dashboard.work_progresses
                    .Include(wp => wp.work_progress_violations)
                    .FirstOrDefaultAsync(wp => wp.id == id);

                if (workProgress == null)
                    return NotFound($"Запись с ID {id} не найдена");

                _dashboard.work_progress_violations.RemoveRange(workProgress.work_progress_violations);
                _dashboard.work_progresses.Remove(workProgress);
                await _dashboard.SaveChangesAsync();
                await LogEvent("Удалена запись", $"Удалена запись на странице аналитики");
                return Ok(new { message = "Запись успешно удалена" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при удалении: {ex.Message}");
            }
        }

        [HttpGet("form/list")]
        public async Task<IActionResult> GetWorkProgressList()
        {
            try
            {
                var list = await _dashboard.work_progresses
                    .Include(wp => wp.id_sourseNavigation)
                    .OrderByDescending(wp => wp.created_at)
                    .Select(wp => new WorkProgressListItem
                    {
                        Id = wp.id,
                        SourseName = wp.id_sourseNavigation.source,
                        AllPerimeter = wp.all_perimeter ?? 0,
                        CompletePerimeter = wp.complete_perimeter ?? 0,
                        CreateAt = wp.created_at ?? DateTime.Now,
                        CreatedByUser = wp.CreatedByUser.FullName 
                    })
                    .ToListAsync();

                return Ok(list);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при получении списка: {ex.Message}");
            }
        }

        [HttpGet("articles")]
        public async Task<IActionResult> GetArticles()
        {
            try
            {
                var article = await _dashboard.articles.ToListAsync();
                return Ok(article);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

        [HttpGet("sources")]
        public async Task<IActionResult> GetSourse()
        {
            try
            {
                var sourse = await _dashboard.sourses.ToListAsync();
                return Ok(sourse);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }

       
        private async Task<int?> GetOrCreateSourceAsync(int idSourse, string? customSourceName)
        {
           
            if (idSourse > 0)
                return idSourse;

            
            if (idSourse == -1 && !string.IsNullOrWhiteSpace(customSourceName))
            {
                var normalizedName = customSourceName.Trim();

                
                var existing = await _dashboard.sourses
                    .FirstOrDefaultAsync(s => s.source.ToLower() == normalizedName.ToLower());

                if (existing != null)
                    return existing.id;

            
                var newSource = new sourse { source = normalizedName };
                return await SafeAddEntityAsync(_dashboard.sourses, newSource);
            }

            return null;
        }

        private async Task<int?> GetOrCreateArticleAsync(int idArticle, string? customArticleName)
        {
           
            if (idArticle > 0)
                return idArticle;

            
            if (idArticle == -1 && !string.IsNullOrWhiteSpace(customArticleName))
            {
                var normalizedName = customArticleName.Trim();

               
                var existing = await _dashboard.articles
                    .FirstOrDefaultAsync(a => a.article1.ToLower() == normalizedName.ToLower());

                if (existing != null)
                    return existing.id;

                
                var newArticle = new article { article1 = normalizedName };
                return await SafeAddEntityAsync(_dashboard.articles, newArticle);
            }

            return null;
        }

        private async Task<int> SafeAddEntityAsync<T>(DbSet<T> dbSet, T entity) where T : class
        {
            try
            {
                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
                return (int)entity.GetType().GetProperty("id")!.GetValue(entity)!;
            }
            catch (DbUpdateException)
            {
                
                _dashboard.Entry(entity).State = EntityState.Detached;
                dbSet.Add(entity);
                await _dashboard.SaveChangesAsync();
                return (int)entity.GetType().GetProperty("id")!.GetValue(entity)!;
            }
        }
    }
}