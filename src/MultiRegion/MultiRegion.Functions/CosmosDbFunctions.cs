using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;
using Microsoft.Extensions.Logging;
using MultiRegion.Functions.Data;

namespace MultiRegion.Functions
{
	public class CosmosDbFunctions
	{
		private readonly string origin = Environment.GetEnvironmentVariable("origin");

		[FunctionName(nameof(NotifyClientOfChanges))]
		public async Task NotifyClientOfChanges
		(
			[CosmosDBTrigger("Global", "Messages", Connection = "CosmosDbGlobalConnectionString", FeedPollDelay = 1000, LeaseConnection = "CosmosDbLocalConnectionString", LeaseDatabaseName = "Local", LeaseContainerName = "Leases")] IReadOnlyList<Message> input,
			[SignalR(HubName = "MessagesHub")] IAsyncCollector<SignalRMessage> signalRMessages,
			ILogger log
		)
		{
			if (input != null && input.Count > 0)
			{
				foreach (var message in input)
				{
					var diff = DateTimeOffset.UtcNow - message.Timestamp;

					await signalRMessages.AddAsync(
						new SignalRMessage
						{
							Target = "AllMessages",
							Arguments = new[] { $"{message.Id}|{message.Origin}|{origin}|{diff}" }
						}
					);
				}
			}
		}
	}
}
