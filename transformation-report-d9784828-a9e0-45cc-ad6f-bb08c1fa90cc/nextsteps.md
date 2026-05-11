# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or any other unintended framework moniker.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that have been deprecated and may need replacement.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate subtle compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

## 4. Run Existing Tests

Execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the built-in compatibility analyzers to identify any remaining calls to Windows-only or platform-specific APIs. You can enable the analyzer in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Run the build again after enabling this and review any new diagnostics.

## 6. Validate Runtime Behavior on Target Platforms

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that static analysis would not surface, such as file path casing sensitivity or OS-specific environment behavior.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime(s):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Use `--self-contained true` if the target environment does not have the .NET runtime installed.

## 8. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.