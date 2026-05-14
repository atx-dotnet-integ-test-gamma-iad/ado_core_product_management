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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that may surface at runtime.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify any outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted .NET Framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET. Review the code for usage of the following common problem areas:

- `System.Web` (not available in .NET Core/.NET 5+)
- `AppDomain` (partially supported)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if needed.

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any test failures that may indicate behavioral differences introduced by the migration.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality manually or through integration tests. Pay attention to:

- Database connectivity (ADO.NET connection strings may need updating)
- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Configuration loading (ensure `app.config` has been migrated to `appsettings.json` if applicable)

## 7. Validate Configuration Migration

If the project previously used `System.Configuration.ConfigurationManager`, confirm it has either been replaced with `Microsoft.Extensions.Configuration` or that the `System.Configuration.ConfigurationManager` NuGet package has been added as a compatibility shim.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output in the `./publish` directory contains all expected binaries and dependencies. If targeting a specific runtime, add the `-r` flag:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained true --output ./publish
```

Adjust the runtime identifier (`win-x64`, `linux-x64`, etc.) to match your deployment target.