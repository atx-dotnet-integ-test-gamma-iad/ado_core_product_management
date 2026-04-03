# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced during the initial transformation analysis:

```bash
dotnet build --configuration Release
```

Address any warnings related to deprecated APIs, nullable reference types, or platform compatibility analyzers before proceeding.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Validate Platform-Specific Code

Check the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, including:

- `System.Drawing` (GDI+ based) — consider `SkiaSharp` or `ImageSharp` as replacements.
- `Microsoft.Win32.Registry` — only functional on Windows.
- `System.Security.Permissions` — partially available; review usage carefully.
- WCF server-side components — not available in cross-platform .NET; consider CoreWCF.

Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to surface any remaining compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze .
```

## 6. Test on Target Platforms

If cross-platform support (Linux, macOS) is a goal, build and run the application on each target operating system to catch platform-specific runtime issues that static analysis may not detect.

```bash
dotnet run --configuration Release
```

## 7. Review Output Artifacts

Confirm the compiled output is placed in the expected location and that all required assets, configuration files, and dependencies are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify the output is complete before distributing or deploying the application.

## 8. Update Documentation

Update any internal documentation, README files, or build instructions that reference the old .NET Framework tooling (e.g., `msbuild`, Visual Studio-only builds) to reflect the new `dotnet` CLI workflow.