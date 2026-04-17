# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages were previously Windows-specific (e.g., targeting `net472`), confirm their cross-platform equivalents are in place.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output. Warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing under .NET Framework that may now fail due to behavioral differences in cross-platform .NET, particularly around:

- File path separators (`\` vs `/`)
- Culture and encoding defaults
- `System.Data` or ADO.NET provider behavior (relevant given the `AdoCore` project name)

## 5. Validate ADO.NET / Data Access Behavior

Given the project name `AdoCore`, it likely involves data access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the correct cross-platform version.
- Connection strings are not hardcoded with Windows-specific paths or authentication methods (e.g., Windows Integrated Security may behave differently on Linux/macOS).
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is replaced or accounted for, as these have limited or no cross-platform support.

## 6. Run on Target Platform

If the intended deployment target is Linux or macOS, test the application explicitly on that platform:

```bash
dotnet run --configuration Release
```

Or publish a self-contained executable for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Supported runtime identifiers (RIDs) include `linux-x64`, `osx-x64`, `osx-arm64`, and `win-x64`.

## 7. Review Platform Compatibility Warnings

Install and run the .NET Upgrade Assistant or the Platform Compatibility Analyzer to catch any remaining platform-specific API usage:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the built-in analyzer by ensuring the following is set in the `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Then rebuild and review any `CA1416` platform compatibility diagnostics.

## 8. Check Configuration and Environment

- Confirm that `app.config` or `web.config` files have been migrated to `appsettings.json` where applicable.
- Ensure environment-specific settings are handled via `IConfiguration` and `appsettings.{Environment}.json`.
- Verify that any registry-based configuration (Windows-only) has been replaced with a cross-platform alternative.