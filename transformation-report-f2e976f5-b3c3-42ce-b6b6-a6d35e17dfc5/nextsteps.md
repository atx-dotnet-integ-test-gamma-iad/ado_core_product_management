# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework (e.g., `net472`), update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages.

## 3. Build the Solution

Perform a clean build to confirm there are no issues:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if they do not block the build.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures before proceeding.

## 5. Validate Runtime Behavior on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) and verify:

- Database connections and ADO.NET operations function correctly, as `AdoCore` suggests data access logic is present.
- Any file path handling uses `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- Any platform-specific APIs (e.g., Windows registry access, COM interop) have been replaced or conditionally compiled.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that behave differently in cross-platform .NET compared to .NET Framework:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:

- `System.Data` and ADO.NET provider behavior differences.
- Configuration APIs (e.g., `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package).
- Any use of `AppDomain` or reflection-based features.

## 7. Review NuGet Package Versions

Open the `.csproj` file and confirm all referenced packages have versions compatible with your target framework. Cross-reference with [NuGet.org](https://www.nuget.org) if needed.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present.