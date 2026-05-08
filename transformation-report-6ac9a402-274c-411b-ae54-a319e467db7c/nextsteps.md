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

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause runtime issues even if they do not produce build errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing and are now failing, as these may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

---

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only at runtime even if they compile successfully:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, review the code manually for usages of:
- `System.Windows.Forms`
- `System.Drawing` (GDI+ based)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-specific libraries

---

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

---

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

Test the core workflows of the application manually or through automated tests on each platform.

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate RID for your target environment (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

---

## 8. Review Output Artifacts

After publishing, verify the contents of the output directory to ensure all expected assemblies, configuration files, and static assets are present before deploying to the target environment.