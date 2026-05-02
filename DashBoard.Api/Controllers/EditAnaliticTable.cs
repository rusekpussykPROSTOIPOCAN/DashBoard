using DashBoard.Lib.Data;
using Microsoft.AspNetCore.Mvc;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/edit-analitic-table")]
    public class EditAnaliticTable:BaseController
    {
        public EditAnaliticTable(dashboardContext dashboard) : base(dashboard)
        {

        }


    }
}
