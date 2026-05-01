# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support your target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause issues at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild and review any new analyzer warnings related to platform compatibility.

## 6. Validate ADO-Specific Functionality

Since the project is named `AdoCore`, it likely involves data access using `System.Data` or related ADO.NET APIs. Manually verify the following at runtime:

- Database connection strings are valid and accessible in the new environment.
- Any `System.Data.OleDb` usage will **not** work on non-Windows platforms. If cross-platform database access is required, replace `OleDb` with a platform-neutral provider such as `Microsoft.Data.SqlClient` for SQL Server or the appropriate provider for your database.
- `System.Data.Odbc` has limited support on non-Windows platforms and should be reviewed.

## 7. Test on Target Platform

If the goal is to run on a non-Windows operating system, execute the application on that platform directly to catch any remaining runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the publish output directory to confirm all required assemblies and configuration files are present before deploying.