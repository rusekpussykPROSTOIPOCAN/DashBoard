using DashBoard.Lib.Data;
using Microsoft.AspNetCore.Mvc;

namespace DashBoard.Api.Controllers
{
    public abstract class BaseController:ControllerBase
    {
        protected readonly dashboardContext _dashboard;
        protected BaseController(dashboardContext dashboard)
        {
            _dashboard = dashboard;
        }
    }
}
