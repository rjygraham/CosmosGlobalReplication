using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;
using Microsoft.Extensions.Logging;

namespace MultiRegion.Functions;

public class MessagesHub : ServerlessHub
{
	[FunctionName("negotiate")]
	public SignalRConnectionInfo Negotiate(
		[HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest req,
		[SignalRConnectionInfo(HubName = "MessagesHub")] SignalRConnectionInfo connectionInfo)
	{
		return connectionInfo;
	}

	[FunctionName(nameof(Broadcast))]
	public async Task Broadcast([SignalRTrigger] InvocationContext invocationContext, string message, ILogger logger)
	{
		await Clients.All.SendAsync("AllMessages", message);
		logger.LogInformation($"{invocationContext.ConnectionId} broadcast {message}");
	}

	[FunctionName(nameof(OnConnected))]
	public async Task OnConnected([SignalRTrigger] InvocationContext invocationContext, ILogger logger)
	{
		await Clients.All.SendAsync("AllMessages", invocationContext.ConnectionId);
		logger.LogInformation($"{invocationContext.ConnectionId} has connected");
	}

	[FunctionName(nameof(OnDisconnected))]
	public void OnDisconnected([SignalRTrigger] InvocationContext invocationContext)
	{
	}
}
