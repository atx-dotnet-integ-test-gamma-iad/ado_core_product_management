# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- **`System.Data`** and ADO.NET usage — verify connection strings and provider factories work as expected on the target platform.
- **`ConfigurationManager`** — this requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET.
- **Platform-specific APIs** — any Windows-only APIs (e.g., registry access, COM interop) will not function on Linux or macOS.

You can use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface these issues.

## 5. Run Existing Tests

If the solution contains test projects, execute them to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the output for any failing tests that may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality, particularly any database connectivity or ADO.NET operations, since this is a core concern for a project named `AdoCore`. Verify:

- Database connections open and close correctly.
- Queries return expected results.
- Transactions behave as expected.
- Exception handling paths function correctly.

## 7. Validate on Target Operating Systems

If cross-platform support is a goal, test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the contents of the publish output directory before deploying to confirm all required assets are present.