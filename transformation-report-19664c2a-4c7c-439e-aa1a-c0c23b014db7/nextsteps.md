# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior around `Assembly.LoadFrom`, `Type.GetType`, and similar APIs can differ.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET. Verify that any `app.config` or `web.config` usage has been accounted for.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop, WMI) will throw `PlatformNotSupportedException` on non-Windows systems. Use `RuntimeInformation.IsOSPlatform` guards where necessary.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their modern equivalents where available.

## 6. Validate ADO-Specific Functionality

Given the project name `AdoCore`, it likely involves data access. Confirm the following:

- The correct ADO.NET provider package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Connection strings and provider factories behave as expected on the target platform.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage still functions correctly, as these are supported but carry some behavioral nuances in cross-platform .NET.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues before deployment.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.