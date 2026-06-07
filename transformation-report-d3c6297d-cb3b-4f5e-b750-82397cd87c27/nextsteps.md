# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm there are no errors or warnings introduced by the toolchain:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the test output carefully. Any failing tests that previously passed may indicate a behavioral difference introduced by the framework migration.

## 4. Verify Platform-Specific Behavior

Since this project was migrated from a legacy .NET Framework codebase, review the following areas for potential runtime issues:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in configuration or code.
- **Registry access**: Any use of `Microsoft.Win32.Registry` will not function on Linux or macOS.
- **Windows Communication Foundation (WCF)**: WCF server-side is not supported on .NET Core/5+. If WCF is used, evaluate replacing it with gRPC or HTTP APIs.
- **`System.Drawing`**: This namespace has limited cross-platform support. Consider replacing it with a library such as `SkiaSharp` if image processing is required.
- **`AppDomain` and Reflection**: Some APIs behave differently or are restricted on modern .NET.

## 5. Review Target Framework

Open the `AdoCore.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and currently supported version:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is targeting `net6.0` or `net7.0`, consider updating to `net8.0` as those versions are approaching or have reached end of life.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant or the compatibility analyzer to identify any API usage that may compile but behave differently at runtime:

```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
```

Review any analyzer diagnostics that appear in the build output.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended platform (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

Review the contents of the `./publish` directory to confirm all expected files and dependencies are present before deploying.