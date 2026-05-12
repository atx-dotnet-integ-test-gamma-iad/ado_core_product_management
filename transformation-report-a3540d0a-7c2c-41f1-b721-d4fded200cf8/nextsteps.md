# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment.

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-specific assemblies (e.g., `System.Data`, `System.Web`) have been replaced with the appropriate NuGet packages or framework-provided equivalents.
- No `<HintPath>` entries point to absolute paths or machine-specific locations.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to current stable versions using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review any warnings produced during the build, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416). Address these where applicable.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failing tests. Failing tests after a migration often indicate:

- Changed exception types or messages from updated APIs.
- Behavioral differences in cross-platform file path handling (`Path.DirectorySeparatorChar`).
- Encoding or culture differences between .NET Framework and modern .NET.

## 5. Validate Cross-Platform Behavior

If the intent is to run on non-Windows operating systems, test the application on the target OS directly:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File system path separators and case sensitivity.
- Use of `Environment.SpecialFolder` paths, which resolve differently per OS.
- Any P/Invoke or `DllImport` calls that reference Windows-only native libraries.

## 6. Check for Removed or Incompatible APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining API usage that is not supported on the target platform:

```bash
dotnet tool install -g dotnet-compatibility
```

Alternatively, enable the platform compatibility warnings in the project file:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:

- `win-x64` for 64-bit Windows
- `linux-x64` for 64-bit Linux
- `osx-x64` for macOS on Intel
- `osx-arm64` for macOS on Apple Silicon

Review the output in the `publish` folder to confirm all required assemblies and configuration files are present before deploying to the target environment.