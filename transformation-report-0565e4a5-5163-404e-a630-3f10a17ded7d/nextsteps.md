# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not be fully compatible with the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality behaves as expected after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures at this stage often point to behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Data` behavior
- ADO.NET provider availability and configuration
- Connection string formats or driver compatibility

## 5. Validate ADO.NET Provider Compatibility

Since this project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is explicitly referenced in the `.csproj` file and is a version compatible with cross-platform .NET.
- Any `DbProviderFactories.RegisterFactory` calls are present where needed, as automatic provider registration from `app.config`/`web.config` is not supported in cross-platform .NET.
- Connection strings previously stored in `app.config` have been migrated to `appsettings.json` or another supported configuration source.

## 6. Review Configuration Files

Check that any configuration previously held in `app.config` or `web.config` has been properly migrated. Cross-platform .NET uses `Microsoft.Extensions.Configuration` with sources such as `appsettings.json`. Confirm:

- `app.config` is no longer the primary configuration source unless explicitly supported by the chosen runtime.
- Any `ConfigurationManager` usages have been replaced or that the `System.Configuration.ConfigurationManager` NuGet package has been added if that approach is intentionally retained.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues such as:

- File path separator differences
- Case-sensitive file system behavior on Linux
- Platform-specific native library dependencies

## 8. Review Output and Publish

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output location.