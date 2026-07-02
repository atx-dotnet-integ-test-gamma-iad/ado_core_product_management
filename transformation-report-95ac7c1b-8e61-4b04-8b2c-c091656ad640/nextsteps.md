# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause issues at runtime even if they do not cause build errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime incompatibilities that were not caught at compile time.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may be present that are Windows-only and will throw `PlatformNotSupportedException` at runtime on Linux or macOS. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review any usages of:
- `System.Windows.Forms`
- `Microsoft.Win32` registry APIs
- `System.Drawing` (requires `System.Drawing.Common` and may have platform restrictions)
- COM interop or P/Invoke calls targeting Windows-only libraries

---

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run the following and inspect the output for any packages that were resolved with fallback compatibility:

```bash
dotnet restore --verbosity detailed
```

Replace any packages that do not natively support your target TFM with maintained cross-platform alternatives where possible.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify functional behavior. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable names and behavior
- Line ending differences (`\r\n` vs `\n`)

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.