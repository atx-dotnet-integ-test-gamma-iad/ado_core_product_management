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

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were silently ignored during transformation.

## 3. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any test failures and address them before proceeding.

## 5. Check for Platform-Specific Code

Since this was a legacy project being migrated to cross-platform .NET, manually review the codebase for any remaining Windows-specific APIs, such as:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+) usage
- COM interop or P/Invoke calls targeting Windows DLLs

If cross-platform support is required, these areas will need to be refactored or conditionally compiled using runtime checks such as `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)`.

## 6. Validate Runtime Behavior

Run the application locally and exercise its primary workflows to confirm that behavior matches the original legacy version:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to database connections, file I/O paths, and any configuration files (e.g., `app.config` vs `appsettings.json`) that may have changed format or location during migration.

## 7. Review Configuration Migration

Legacy .NET Framework projects used `app.config` with `ConfigurationManager`. Cross-platform .NET projects typically use `appsettings.json` with `Microsoft.Extensions.Configuration`. Confirm that:

- All configuration values have been moved to `appsettings.json` or equivalent.
- `ConfigurationManager` references have been replaced, or the `System.Configuration.ConfigurationManager` NuGet package has been explicitly added if backward compatibility is needed.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.