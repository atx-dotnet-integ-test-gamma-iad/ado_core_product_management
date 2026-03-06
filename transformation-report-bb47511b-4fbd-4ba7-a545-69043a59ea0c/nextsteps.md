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

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were carried over from the legacy project.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced during the migration.

## 5. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- COM interop or P/Invoke calls

If any such code exists, verify it either has a cross-platform equivalent or is guarded with a runtime platform check:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, and that `ConfigurationManager` usage has been replaced with `Microsoft.Extensions.Configuration` if needed.

## 7. Smoke Test the Application

Run the application directly and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that the application behaves as expected and that no runtime exceptions surface from code paths that were not covered by automated tests.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).