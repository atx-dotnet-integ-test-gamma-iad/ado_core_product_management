# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

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

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the original project:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Ensure no projects are still referencing `net48` or other Windows-only frameworks unless intentional.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference Windows-specific APIs that will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any reported diagnostics and replace platform-specific calls with cross-platform alternatives where applicable.

## 6. Validate Configuration and App Settings

If the project uses configuration files such as `App.config` or `Web.config`, confirm these have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in modern .NET.

## 7. Test on Target Platforms

Run and test the application on each platform you intend to support (Windows, Linux, macOS) to surface any runtime platform-specific issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained false` if you prefer a framework-dependent deployment.

## 9. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.