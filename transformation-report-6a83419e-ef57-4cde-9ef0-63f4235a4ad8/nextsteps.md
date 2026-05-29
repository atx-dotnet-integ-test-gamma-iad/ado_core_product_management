# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings that may indicate compatibility issues, deprecated APIs, or platform-specific code paths that were silently retained.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration to cross-platform .NET.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, the code may still contain Windows-specific APIs that will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages such as:
- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (without the `EnableWindowsFormsHighDpiAutoResizingPolicy` workaround)
- P/Invoke calls targeting Windows-only DLLs (e.g., `kernel32.dll`, `user32.dll`)
- Registry access via `RegistryKey`

---

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that only supported `net45` or similar legacy TFMs may have been retained and could cause runtime issues.

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer versions compatible with your target framework.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform compatibility issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity in file system access
- Environment variable differences across OSes

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

---

## 8. Review Output Artifacts

After publishing, verify the contents of the output directory to ensure all required assets, configuration files, and dependencies are present before deploying to the target environment.