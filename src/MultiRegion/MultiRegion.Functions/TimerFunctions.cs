using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using MultiRegion.Functions.Data;

namespace MultiRegion.Functions;
public class TimerFunctions
{
	private readonly string origin = Environment.GetEnvironmentVariable("origin");

	[FunctionName(nameof(CreateRecord))]
	public void CreateRecord(
		[TimerTrigger("*/5 * * * * *")] TimerInfo myTimer,
		[CosmosDB("Global", "Messages", Connection = "CosmosDbGlobalConnectionString")] out Message document,
		ILogger log
	)
	{
		document = new Message { Id = Guid.NewGuid().ToString(), Origin = origin, Timestamp = DateTimeOffset.UtcNow };
	}
}
