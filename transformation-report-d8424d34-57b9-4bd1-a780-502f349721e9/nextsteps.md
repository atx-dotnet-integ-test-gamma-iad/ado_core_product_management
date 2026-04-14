# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are targeting compatible versions for the selected .NET target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the source code for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security or identity APIs
- `AppDomain` usage
- `BinaryFormatter` (removed or obsolete in modern .NET)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Validate ADO.NET / Database Connectivity

Since the project name suggests ADO.NET usage, verify that the correct database driver NuGet packages are referenced and functional. For example:

- SQL Server: `Microsoft.Data.SqlClient`
- SQLite: `Microsoft.Data.Sqlite`
- Other providers: confirm they have .NET-compatible versions

Test actual database connections in a development environment to confirm connectivity and query behavior.

## 7. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Observe the output for any runtime exceptions or unexpected behavior.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 9. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.