# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs that compiled successfully may behave differently or throw exceptions at runtime on cross-platform .NET. Pay particular attention to:

- **Windows-only APIs**: Features such as the registry, certain `System.Drawing` methods, or COM interop may not function on non-Windows platforms. Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.
- **`app.config` / `web.config`**: Configuration handling has changed. Migrate to `appsettings.json` and `Microsoft.Extensions.Configuration` if not already done.
- **`System.Web` dependencies**: These are not available in cross-platform .NET. Ensure any such dependencies have been replaced with ASP.NET Core equivalents.

## 5. Review NuGet Package Versions

Confirm that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Check for packages that may still reference .NET Framework-specific versions:

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests after each significant update.

## 6. Test Data Access Behavior

Given the `AdoCore` naming convention, this project likely involves ADO.NET or database access. Validate the following at runtime:

- Connection strings are correctly configured for the new environment.
- Database providers (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`) are being used where applicable.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions as expected, as these are supported but carry known behavioral nuances.

## 7. Run on Target Platform

If the intent is cross-platform deployment, test the application explicitly on the target operating system (Linux or macOS) to surface any platform-specific issues that would not appear on Windows:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust `--runtime` and `--self-contained` as needed for your deployment target. Review the published output directory to confirm all required files are present.