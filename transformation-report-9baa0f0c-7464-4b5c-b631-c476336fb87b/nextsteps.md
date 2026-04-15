# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before migration may indicate runtime behavioral differences between the legacy .NET Framework and the current .NET runtime.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but may behave differently or be absent in cross-platform .NET. Common areas to check include:

- `System.Configuration` (use `Microsoft.Extensions.Configuration` as a replacement)
- `System.Web` (not available outside of Windows-specific compatibility shims)
- Windows Registry access
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` usage, which has limited support in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended target operating system (e.g., Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

## 6. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` value reflects the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If long-term support is a priority, ensure you are targeting an LTS release of .NET (e.g., .NET 8).

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment environment (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

## 8. Review Output Artifacts

Inspect the `publish` output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.