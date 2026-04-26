# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that could indicate deprecated APIs or packages that may cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-specific and may fail on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop or P/Invoke calls
- `System.Drawing` usage (requires `libgdiplus` on non-Windows platforms)

## 5. Validate NuGet Package Compatibility

Review all NuGet package references in `AdoCore.csproj` and ensure each package supports the target framework. Check [nuget.org](https://www.nuget.org) for each dependency and confirm a compatible version exists. Replace any packages that only support `.NET Framework` with their cross-platform equivalents.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime errors that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform (example: Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.