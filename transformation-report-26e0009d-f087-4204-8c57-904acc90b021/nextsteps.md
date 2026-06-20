# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the output for any warnings, even if there are no errors. Warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes may indicate areas that need attention.

## 4. Run Existing Tests

If the solution contains test projects, run them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in:

- `System.Text.RegularExpressions` behavior
- `HttpClient` defaults
- Globalization and culture handling
- Reflection behavior

## 5. Check for Platform Compatibility

If `AdoCore` interacts with Windows-specific APIs (such as the Windows Registry, WMI, COM interop, or `System.Drawing`), run the .NET Compatibility Analyzer to surface any platform-specific API usage:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

For any flagged APIs, evaluate whether a cross-platform alternative exists or whether a platform guard (`OperatingSystem.IsWindows()`) is appropriate.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface at compile time.

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`/` vs `\`)
- Case-sensitive file systems on Linux
- Environment variable differences

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime on the target machine):**

```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. A full list of runtime identifiers is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).