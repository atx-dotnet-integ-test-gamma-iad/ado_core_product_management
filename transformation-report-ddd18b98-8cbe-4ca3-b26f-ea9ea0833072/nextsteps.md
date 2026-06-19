# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as hard errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

---

## 4. Check for Windows-Specific API Usage

Even when a project builds successfully, it may still contain APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any `CA1416` platform compatibility warnings that appear after adding the analyzer. These warnings indicate calls to Windows-only APIs that could fail on Linux or macOS.

---

## 5. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (Windows-only)
- `System.Drawing` usage (requires `libgdiplus` on Linux or replacement with a cross-platform library)
- COM interop or P/Invoke calls targeting Windows-specific native libraries

---

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the new target framework. Run the following to inspect the dependency graph:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that have newer versions compatible with your target framework, and replace any that are flagged as unsupported.

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly in the target environment.