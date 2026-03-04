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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to inspect include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Reflection APIs
- Windows-specific registry or file path assumptions

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) if a deeper API compatibility scan is needed.

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to validate runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its core functionality manually. Pay particular attention to:

- Database connectivity (if ADO.NET is in use, given the project name `AdoCore`)
- Connection string formats and provider names, which may differ between .NET Framework and .NET
- Any configuration previously stored in `app.config` or `web.config` that should now reside in `appsettings.json`

## 7. Validate Configuration Migration

If the project previously used `System.Configuration.ConfigurationManager`, confirm that configuration has been migrated to the `Microsoft.Extensions.Configuration` model or that the `System.Configuration.ConfigurationManager` NuGet package has been added as a compatibility shim.

## 8. Test on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file system behavior on Linux
- Platform-specific native library dependencies

## 9. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform (example: Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.