using System;
using Newtonsoft.Json;

namespace MultiRegion.Functions.Data;

public class Message
{
	[JsonProperty("id")]
	public string Id { get; set; }

	[JsonProperty("origin")]
	public string Origin { get; set; }

	public DateTimeOffset Timestamp { get; set; }
}