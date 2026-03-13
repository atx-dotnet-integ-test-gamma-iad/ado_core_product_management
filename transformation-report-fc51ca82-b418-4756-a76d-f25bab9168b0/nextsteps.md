# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `net4x` or `netstandard` with their modern equivalents where applicable.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime (e.g., changes in `System.Data`, threading, or serialization behavior).

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer in the project file:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild after adding this and review any new diagnostics.

## 6. Test on Target Platforms

If cross-platform support is a requirement, run the build and tests on each target operating system (Windows, Linux, macOS) to surface any runtime differences:

```bash
dotnet test --runtime linux-x64
dotnet test --runtime win-x64
dotnet test --runtime osx-x64
```

## 7. Publish the Application

Once validation is complete, publish the application for the intended target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment requirements. Use `--self-contained true` if the target environment does not have the .NET runtime installed.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.