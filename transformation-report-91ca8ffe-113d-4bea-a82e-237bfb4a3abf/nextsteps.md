# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee functional correctness, so test coverage is critical at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

Ensure no projects are still referencing `net48` or other legacy framework monikers unless intentionally targeting multiple frameworks via `<TargetFrameworks>`.

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may cause runtime failures on non-Windows systems:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to warnings prefixed with `CA1416`, which flag platform-specific API usage.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation.

## 7. Review Configuration and File Paths

Inspect any hardcoded file paths, registry access, or Windows-specific configuration patterns in the codebase. Replace these with cross-platform alternatives such as `Path.Combine`, `Environment.GetFolderPath`, or `Microsoft.Extensions.Configuration`.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.