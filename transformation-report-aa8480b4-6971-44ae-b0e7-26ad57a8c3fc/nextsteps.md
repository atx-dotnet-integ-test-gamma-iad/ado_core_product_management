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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that may have been removed or changed between .NET Framework and modern .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs if this project deals with data access
- Any platform-specific APIs that may not behave identically on Linux or macOS

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they indicate a behavioral difference introduced by the migration.

## 6. Perform Runtime Smoke Testing

Run the application and exercise its primary code paths manually or via integration tests. Confirm that:
- Database connections (if applicable) open and close correctly
- Data reads and writes produce expected results
- Any configuration files (e.g., `appsettings.json` replacing `app.config`) are loaded correctly

## 7. Validate Cross-Platform Behavior

If cross-platform support is a goal, test the application on at least one non-Windows OS (Linux or macOS):

```bash
dotnet run --configuration Release
```

Check for issues related to:
- File path separators (`/` vs `\`)
- Case-sensitive file systems
- Platform-specific dependencies that may have been carried over from the legacy project

## 8. Review Configuration Migration

If the original project used `app.config` or `web.config`, confirm that settings have been correctly migrated to `appsettings.json` or environment variables, and that they are being read using `Microsoft.Extensions.Configuration` where appropriate.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all required runtime assets are present before deploying to the target environment.