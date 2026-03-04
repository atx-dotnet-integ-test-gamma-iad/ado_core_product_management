# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches and update them as needed via the `.csproj` file or `dotnet add package`.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate API usage that is obsolete or behaves differently on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Pay particular attention to tests that exercise database access, file I/O, or platform-specific behavior, as these areas are most likely to surface cross-platform issues.

## 5. Validate ADO.NET Functionality

Since this project is named `AdoCore`, it likely contains ADO.NET data access logic. Verify the following:

- **Connection strings** are not hardcoded with Windows-specific paths or authentication modes (e.g., `Integrated Security=True` may not work on Linux/macOS).
- **Database drivers** (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform versions. `Microsoft.Data.SqlClient` is the recommended cross-platform package.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` should be reviewed, as these have limited or no support on non-Windows platforms.

## 6. Test on Target Platform

If the goal is to run on Linux or macOS, execute the application on that platform directly or copy the published output and run it there:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then run the published output on the target machine to catch any remaining platform-specific issues.

## 7. Review for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to check for any API usage that may have been removed or changed between .NET Framework and modern .NET:

```bash
dotnet tool install -g dotnet-compatibility
```

This can surface issues that do not cause build errors but may cause runtime exceptions.

## 8. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used where appropriate.