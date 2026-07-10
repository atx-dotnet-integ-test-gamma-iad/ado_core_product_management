# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original legacy project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

## 4. Validate Platform-Specific Behavior

Since this was a legacy project migration, check for any areas in the code that may have relied on Windows-specific APIs or behaviors. Common areas to inspect include:

- File path handling (`\` vs `/`) — prefer `Path.Combine()` and `Path.DirectorySeparatorChar`
- Registry access (`Microsoft.Win32.Registry`) — not available on non-Windows platforms
- Windows-specific interop (`DllImport` with system DLLs)
- `System.Drawing` — limited cross-platform support; consider `SkiaSharp` or `ImageSharp` as alternatives

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. You can audit this with:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if the .NET runtime is not guaranteed to be installed on the target machine.

## 8. Review Output Artifacts

After publishing, verify the contents of the `publish` output directory to ensure all required assemblies, configuration files, and assets are present before deploying to the target environment.