# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues, even if they are not hard errors.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between .NET Framework and modern .NET.

---

## 4. Check for Windows-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of:
- `System.Windows.Forms` or `System.Web`
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- Windows-specific file path assumptions (e.g., backslash separators)

---

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies support your target framework. Open the `.csproj` file and review each `<PackageReference>`. Visit [nuget.org](https://www.nuget.org) to confirm each package supports the target TFM. Replace or remove any packages that only support .NET Framework.

---

## 6. Test on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application on the intended non-Windows platform:

```bash
dotnet run --configuration Release
```

Observe any runtime exceptions that would not have appeared during the Windows build.

---

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`, `linux-arm64`) as appropriate.

---

## 8. Review Output Artifacts

After publishing, verify the contents of the output directory to ensure all expected assemblies, configuration files, and assets are present before deploying to the target environment.