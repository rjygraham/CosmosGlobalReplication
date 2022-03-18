using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.Configuration;
using MultiRegion.Client.Options;

Console.ForegroundColor = ConsoleColor.White;
Console.WriteLine("Reading configuration...");

var configuration = LoadConfiguration();

var region1 = new RegionOptions();
configuration.GetSection("Region1").Bind(region1);

var region2 = new RegionOptions();
configuration.GetSection("Region2").Bind(region2);

var region3 = new RegionOptions();
configuration.GetSection("Region3").Bind(region3);

Console.ForegroundColor = ConsoleColor.White;
Console.WriteLine("Initializing SignalR connections...");

// Start SignalR connections to receive messages
await StartConnectionAsync(region1.RegionName, region1.FunctionAppBaseUri, region1.FunctionAppKey);
await StartConnectionAsync(region2.RegionName, region2.FunctionAppBaseUri, region2.FunctionAppKey);
await StartConnectionAsync(region3.RegionName, region3.FunctionAppBaseUri, region3.FunctionAppKey);

Console.ForegroundColor = ConsoleColor.White;
Console.WriteLine("Awaiting new messages, press [Enter] to exit.");

Console.ReadLine();

async Task StartConnectionAsync(string region, string url, string code)
{
	var connection = new HubConnectionBuilder().WithUrl(url, config =>
	{
		config.Headers["x-functions-key"] = code;
	})
	.WithAutomaticReconnect().
	Build();

	connection.On<string>("AllMessages", x => OnMessage(x));
	await connection.StartAsync();

	Console.ForegroundColor = ConsoleColor.Green;
	Console.WriteLine($"Successfully connected: {region}");
}

void OnMessage(string message)
{
	var segments = message.Split('|');

	if (segments[2].Equals("eastus", StringComparison.OrdinalIgnoreCase))
	{
		Console.ForegroundColor = ConsoleColor.Magenta;
	}
	else if (segments[2].Equals("westus3", StringComparison.OrdinalIgnoreCase))
	{
		Console.ForegroundColor = ConsoleColor.Cyan;
	}
	else
	{
		Console.ForegroundColor = ConsoleColor.Yellow;
	}
	Console.WriteLine(message);
}

IConfiguration LoadConfiguration()
{
	var builder = new ConfigurationBuilder();
	// tell the builder to look for the appsettings.json file
	builder
		.AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
		.AddUserSecrets<Program>(true, false);

	return builder.Build();
}
