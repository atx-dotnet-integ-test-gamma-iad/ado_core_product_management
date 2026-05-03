# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

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

Review the output for any warnings about deprecated packages or version mismatches. If any packages targeting only .NET Framework are present, locate cross-platform equivalents on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not block compilation.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs
- Reflection behavior differences
- Globalization and encoding defaults

## 5. Validate Database Connectivity (ADO-Specific)

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Perform the following checks:

- Confirm the database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the cross-platform compatible version.
- Test all connection strings in your configuration files to ensure they resolve correctly in the new runtime environment.
- Execute integration tests or manual tests that exercise data read and write operations against your target database.

## 6. Check Configuration Files

Cross-platform .NET does not use `App.config` or `Web.config` in the same way as .NET Framework. Verify the following:

- If `App.config` was used, confirm whether it has been migrated to `appsettings.json` or another supported configuration mechanism.
- Confirm that `ConfigurationManager` usage, if any, is backed by the `System.Configuration.ConfigurationManager` NuGet package or has been replaced with `Microsoft.Extensions.Configuration`.

## 7. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators
- Case-sensitive file systems (Linux)
- Platform-specific API calls that may throw `PlatformNotSupportedException`

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all required files are present before deploying to the target environment.