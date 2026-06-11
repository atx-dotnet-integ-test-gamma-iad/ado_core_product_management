# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were carried over from the legacy project.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether failures are due to behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- `System.Security.Permissions`

## 6. Perform Runtime Smoke Testing

Run the application and exercise its primary code paths manually or through integration tests. Confirm that:
- Database connections (given the `AdoCore` name suggests ADO.NET usage) open and close correctly.
- Queries return expected results.
- Transactions behave as expected.
- Connection string configuration is correctly read from the new configuration system (e.g., `appsettings.json` rather than `app.config` or `web.config` if applicable).

## 7. Validate Configuration Migration

If the legacy project used `app.config` or `web.config`, confirm that relevant settings have been moved to `appsettings.json` or environment variables, and that they are being read correctly using `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files are present, then deploy the contents to the target environment.