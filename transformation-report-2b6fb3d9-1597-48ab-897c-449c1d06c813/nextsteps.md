# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate subtle compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failing or skipped tests. Skipped tests may indicate platform-specific code that was not fully migrated.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the following command to scan for APIs that may not be supported on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` (platform compatibility) warnings, which indicate APIs that are Windows-only or otherwise platform-restricted.

## 6. Validate Runtime Behavior

Run the application on each intended target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Test all major application workflows, particularly any that previously relied on Windows-specific features such as the registry, COM interop, or `System.Windows.Forms`.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release as appropriate:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Review the output directory to confirm all required assets and dependencies are present before deploying.