# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may fail on Linux or macOS. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to analyzer warnings prefixed with `CA1416` (platform compatibility).

## 5. Validate Runtime Behavior on Target Platforms

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) and verify that core functionality behaves as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (not available on Linux/macOS)
- Windows-specific authentication or security APIs

## 6. Review NuGet Package Versions

Check that all NuGet dependencies reference versions compatible with the target framework. Run the following to list outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and re-run the build and tests after each update.

## 7. Publish the Application

Once validation is complete, publish the application for the desired runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the output in the `publish` folder before deploying to the target environment.