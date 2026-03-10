# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously targeting `.NET Framework` were carried over, check for their cross-platform equivalents on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate runtime issues even if the build succeeds.

## 4. Run Existing Tests

If the project contains a test project, execute the test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests may indicate behavioral differences between .NET Framework and cross-platform .NET, such as:

- Changes in globalization and culture handling (`Invariant Mode`)
- Differences in `System.Drawing` or other Windows-specific APIs
- File path separator differences (`\` vs `/`)
- Changes in reflection behavior

## 5. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:

- `Microsoft.Win32` registry APIs
- `System.Drawing` (GDI+)
- Windows-specific `PInvoke` calls
- `System.Security.Permissions` attributes

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application explicitly on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions.

```bash
dotnet run --configuration Release
```

## 7. Review Output Artifacts

Confirm the build output in the `bin/Release/net8.0/` directory contains the expected assemblies and that no unintended `.config` or legacy files were carried over from the original .NET Framework project.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.