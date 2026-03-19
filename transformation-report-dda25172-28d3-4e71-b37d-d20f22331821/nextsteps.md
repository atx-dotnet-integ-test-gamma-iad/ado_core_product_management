# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not prevent compilation.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any test failures that may indicate behavioral differences introduced by the migration, particularly around areas such as:
- Data access (ADO.NET connection strings, provider names)
- Configuration (e.g., `System.Configuration` vs `Microsoft.Extensions.Configuration`)
- Serialization behavior changes between .NET Framework and .NET

## 4. Validate ADO.NET Provider Registration

Since the project is named `AdoCore`, it likely uses ADO.NET. In .NET (Core), database providers are not automatically registered. Confirm that the required provider (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) is explicitly referenced in the `.csproj` file and that any provider factory usage registers the provider at startup.

```csharp
// Example for Microsoft.Data.SqlClient
DbProviderFactories.RegisterFactory("Microsoft.Data.SqlClient", Microsoft.Data.SqlClient.SqlClientFactory.Instance);
```

## 5. Review Configuration Files

If the project previously relied on `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET unless the `System.Configuration.ConfigurationManager` NuGet package is explicitly added.

## 6. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to surface any remaining platform-specific API calls that may compile but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any `CA1416` or similar platform compatibility warnings in the build output.

## 7. Test on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application and its tests on the target operating system to catch any runtime issues not surfaced during compilation on Windows.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required runtime assets and dependencies are present before deploying to the target environment.