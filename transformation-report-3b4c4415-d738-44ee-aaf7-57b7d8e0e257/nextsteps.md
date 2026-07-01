# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been deprecated.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings about platform compatibility, nullable reference types, or obsolete APIs before proceeding.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as:

- Changes in `System.Data` or ADO.NET provider behavior
- Differences in connection string handling
- Platform-specific APIs that are no longer available

## 5. Check for Windows-Specific API Usage

Since this project is named `AdoCore` and likely involves data access, verify that any database drivers or ADO.NET providers used are compatible with cross-platform .NET. Common areas to check:

- **OLE DB**: `System.Data.OleDb` is Windows-only. If used, it must be replaced with a cross-platform provider.
- **ODBC**: `System.Data.Odbc` has limited cross-platform support depending on the driver.
- **SQL Server**: Ensure you are using `Microsoft.Data.SqlClient` rather than `System.Data.SqlClient`.
- **Oracle, MySQL, PostgreSQL**: Confirm the NuGet package versions support the target framework.

You can use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls.

## 6. Validate Configuration and Connection Strings

.NET no longer uses `App.config` or `Web.config` in the same way as .NET Framework. Confirm that:

- Connection strings have been moved to `appsettings.json` or environment variables if applicable.
- Any `ConfigurationManager` usage has been replaced with `Microsoft.Extensions.Configuration` or the `System.Configuration.ConfigurationManager` NuGet package has been explicitly added if backward compatibility is needed.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assemblies and configuration files are present.