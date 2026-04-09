# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that should be updated.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, string handling, or timezone behavior).

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze ./AdoCore.csproj
```

Pay particular attention to:
- `System.Drawing` (requires `libgdiplus` on Linux)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific COM interop

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` support the target framework. Open the `.csproj` file and cross-reference each package version against [nuget.org](https://www.nuget.org) to confirm `.NET` compatibility. Replace any packages that only support `.NET Framework` with their cross-platform equivalents.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.