# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were carried over from the legacy project.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs that existed in .NET Framework may behave differently or have been replaced in cross-platform .NET. Review the Microsoft [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) output if available, and check for any usage of:

- `System.Web` namespaces (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, Windows identity)
- `App.config` / `Web.config` (replaced by `appsettings.json` and `IConfiguration`)

## 5. Run Existing Tests

If a test project exists in the solution, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may surface behavioral differences between .NET Framework and cross-platform .NET that were not caught at compile time.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary code paths manually or through integration tests:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:

- Database connectivity and ADO.NET operations (given the `AdoCore` naming suggests data access)
- Connection string configuration, which may have moved from `App.config` to `appsettings.json`
- Any platform-specific behavior if the original project was Windows-only

## 7. Validate Configuration Migration

If the project previously used `App.config` or `Web.config`, confirm that all connection strings and application settings have been correctly moved to `appsettings.json` and are being read via `IConfiguration`. Example:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files are present before deploying to the target environment.