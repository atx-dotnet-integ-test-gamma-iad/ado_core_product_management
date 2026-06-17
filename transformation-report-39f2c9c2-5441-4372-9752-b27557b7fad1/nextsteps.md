# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that previously passed on .NET Framework but now fail, as these may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, reflection, or threading behavior).

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but are absent or behave differently in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package can assist in identifying these.

Common areas to check:
- `AppDomain` usage
- `BinaryFormatter` serialization
- `System.Web` dependencies
- Windows Registry access
- COM interop

## 5. Check Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and supported TFM, such as:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the application must remain Windows-specific, ensure the TFM reflects that:

```xml
<TargetFramework>net8.0-windows</TargetFramework>
```

## 6. Review Configuration Files

If the project previously relied on `app.config` or `web.config`, verify that settings have been migrated to `appsettings.json` or the appropriate modern configuration provider. The `System.Configuration.ConfigurationManager` NuGet package is available if direct migration is not yet feasible.

## 7. Run the Application

Execute the application manually and exercise its primary workflows to confirm end-to-end functionality:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

To produce a self-contained executable that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).