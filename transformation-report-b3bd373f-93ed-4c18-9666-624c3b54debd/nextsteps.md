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

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage or deprecated packages.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-only. These will typically be marked with `[SupportedOSPlatform("windows")]`. If your target deployment includes Linux or macOS, these calls will need to be replaced or conditionally compiled.

You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

---

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package supports the target framework. Visit [nuget.org](https://www.nuget.org) to verify compatibility if any packages were carried over from the legacy project.

Outdated packages can be identified with:

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName>
```

---

## 6. Validate Runtime Behavior

Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (Windows-only)
- Windows-specific libraries such as `System.Drawing` or `Microsoft.Win32`

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

**Framework-dependent (smaller output, requires .NET runtime installed):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes the runtime, no external dependency):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate RID for your target environment (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

---

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published executable directly to perform a final smoke test before deploying to the target environment.