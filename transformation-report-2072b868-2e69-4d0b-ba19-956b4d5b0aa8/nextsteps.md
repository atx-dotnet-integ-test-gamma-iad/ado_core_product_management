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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs behave differently or are unsupported on non-Windows platforms at runtime. Review the code for usage of the following:

- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls
- `AppDomain` usage beyond what is supported in modern .NET
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining concerns.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies reference packages that support your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework moniker.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during compilation.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.