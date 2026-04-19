# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that could indicate deprecated APIs or packages that may cause runtime issues even if they do not cause build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some APIs that compiled successfully may behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Pay particular attention to:

- Any usage of `System.Drawing` (consider replacing with a cross-platform alternative such as `SkiaSharp` or `ImageSharp`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client or server code
- `AppDomain` usage beyond what is supported in .NET Core and later
- COM interop or P/Invoke calls targeting Windows-specific native libraries

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 6. Validate ADO.NET or Data Access Behavior

Given the project name `AdoCore`, it likely involves data access. Verify the following:

- Connection strings are correctly configured for the target environment.
- Any database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are updated to versions compatible with your target framework.
- Data access operations produce correct results against your database by running integration or smoke tests.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.