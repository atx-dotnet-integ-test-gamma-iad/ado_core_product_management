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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages and re-run the build to confirm nothing breaks.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Runtime-Specific Behavior

Some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **File path separators**: Use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If the code uses the registry, add a Windows-specific runtime check or replace with a cross-platform alternative.
- **`System.Drawing`**: This namespace has limited cross-platform support. Consider replacing it with a library such as `SkiaSharp` if cross-platform image processing is needed.
- **`AppDomain`**: Some `AppDomain` members are not supported on cross-platform .NET and will throw `PlatformNotSupportedException` at runtime.

## 6. Run on Target Platforms

If cross-platform support is a goal, run and manually test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions.

## 7. Publish the Application

Once testing is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish/win-x64
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish/linux-x64
```

Replace the runtime identifiers (`win-x64`, `linux-x64`) with those matching your target environments.

## 8. Validate the Published Output

Navigate to the publish output directory and run the produced executable or assembly directly to confirm it starts and operates correctly in the published form before distributing it.