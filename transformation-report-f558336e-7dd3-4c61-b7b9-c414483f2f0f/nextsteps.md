# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Review NuGet Package Compatibility

Check all NuGet dependencies in `AdoCore.csproj` to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Packages that reference `net4x` only may cause runtime failures even if the build succeeds.

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages accordingly.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or globalization).

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that could break on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any `CA1416` platform compatibility warnings that appear after adding the analyzer.

## 6. Validate ADO.NET Functionality

Since the project is named `AdoCore`, confirm that all database connectivity and query logic works correctly at runtime:

- Test all connection string formats, as some providers behave differently on cross-platform .NET.
- Verify that the ADO.NET provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the cross-platform compatible version and not the legacy .NET Framework-only version.
- Execute integration tests against a real or test database instance to confirm query results, transactions, and error handling behave as expected.

## 7. Validate Configuration and Environment

Confirm that any configuration previously loaded via `ConfigurationManager` (which behaves differently in modern .NET) has been migrated to `Microsoft.Extensions.Configuration` or that the `System.Configuration.ConfigurationManager` NuGet package has been added if the legacy approach is still in use.

```bash
dotnet add package System.Configuration.ConfigurationManager
```

## 8. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 9. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder before deploying to the target environment.